#include <string.h>

#define MASTER_KEY_ADDR 0x6A00 // 64 bytes

#define METADATA_ADDR 0x140
#define METADATA_SIZE 4 // 2-byte ERmin, 2-byte ERmax.
#define ERMIN_ADDR METADATA_ADDR
#define ERMAX_ADDR (ERMIN_ADDR + 2)

#define CHAL_ADDR 0x320
#define ATOKEN_CTRL (CHAL_ADDR + 32)

#define ENC_KEY_ADDR 0x360
#define CTR_ADDR 0xffc0

#define AUTH_HANDLER 0xa0aa


extern void hmac(uint8_t *mac, uint8_t *key, uint32_t keylen, uint8_t *data, uint32_t datalen);


void my_memset(uint8_t* ptr, uint8_t val, size_t len) 
{
  size_t i;
  for(i=0; i<len; i++)
  {
    ptr[i] = val;
  } 
}

void *my_memcpy(uint8_t *dst, const uint8_t *src, size_t len)
{
  size_t i;
  for (i=0; i<len; i++) {
    dst[i] = src[i];
  }
  return dst;
}


__attribute__ ((section (".do_mac.call"))) void Hacl_HMAC_SHA2_256_hmac_entry() 
{
  uint8_t key[64] = {0};

  // Check if challenge value is greater than the latest challenge/counter
  if (memcmp((uint8_t*) CHAL_ADDR, (uint8_t*) CTR_ADDR, 32) > 0)
  {
    // Copy the master key from MASTER_KEY_ADDR to the key buffer.
    memcpy(key, (uint8_t*)MASTER_KEY_ADDR, 64);
    
    // Compute HMAC on master key and challenge to generate derived key.
    hmac((uint8_t*) key, (uint8_t*) key, (uint32_t) 64, (uint8_t*)CHAL_ADDR, (uint32_t) 32);
    
    // Compute HMAC on the ER using the above atoken_prv.
    uint8_t atoken_prv[32] = {0};
    uint8_t *ER_min = (uint8_t*)(*((uint16_t*)ERMIN_ADDR));
    uint32_t ER_size = (uint32_t)(*((uint16_t*)(ERMAX_ADDR)) - *((uint16_t*)(ERMIN_ADDR)) + 2);
    hmac((uint8_t*) atoken_prv, (uint8_t*) key, (uint32_t) 32, (uint8_t*)ER_min, (uint32_t) ER_size);
    
    // If verification of ER succeeds, write the derived key to the encryption key address.
    if (memcmp((uint8_t*) ATOKEN_CTRL, (uint8_t*)atoken_prv, (uint32_t) 32) == 0)
    {
      // If control (pc) reaches this point, then authentication is successful.
      // VERSA hardware instantly grants access to GPIO to ER from this point (until ER ends or not modified).

      // Update the CTR to match the current challenge, so that next time it cannot be replayed.
      memcpy((uint8_t*) CTR_ADDR, (uint8_t*) CHAL_ADDR, 32);
      
      // Write derived encryption key to ENC_KEY_ADDR for ER's use.
      memcpy((uint8_t*)ENC_KEY_ADDR, (uint8_t*) key, 32);
    }
  }

  // setting the return addr:
  __asm__ volatile("mov    #0x0300,   r5" "\n\t");
  __asm__ volatile("mov    @(r5),     r5" "\n\t");

  // jump to exit function:
  __asm__ volatile("add     #64,    r1" "\n\t");
  __asm__ volatile( "br      #__mac_leave" "\n\t");
}

__attribute__ ((section (".do_mac.leave"))) __attribute__((naked)) void Hacl_HMAC_SHA2_256_hmac_exit() 
{
  __asm__ volatile("br   r5" "\n\t");
}

// Wrapper function that can be called by external/untrusted applications
void pps_authenticate() 
{
  //Disable interrupts:
  __dint();

  // Save current value of r5:
  __asm__ volatile("push    r5" "\n\t");

  // Save the original value of the Stack Pointer (R1) to RAM:
  __asm__ volatile("mov    #0x0310,   r5" "\n\t");
  __asm__ volatile("mov    r1,   @(r5)" "\n\t");

  // Set the stack pointer to the base of the exclusive stack:
  __asm__ volatile("mov    #0x1002,     r1" "\n\t");

  // Write return address of Hacl_HMAC_SHA2_256_hmac_entry to RAM:
  __asm__ volatile("mov    #0x0300,   r5" "\n\t");
  __asm__ volatile("mov    #0x0004,   @(r5)" "\n\t");
  __asm__ volatile("add    r0,        @(r5)" "\n\t");
  
  // Call SW-Att:
  Hacl_HMAC_SHA2_256_hmac_entry();

  // Copy retrieve the original stack pointer value:
  __asm__ volatile("mov    #0x0310,   r5" "\n\t");
  __asm__ volatile("mov    @(r5),     r1" "\n\t");

  // Restore original r5 values:
  __asm__ volatile("pop   r5" "\n\t");

  // Enable interrupts:
  __eint();
}
