#include <stdio.h>
#include "hardware.h"

#define WDTCTL_              0x0120    /* Watchdog Timer Control */
#define WDTHOLD             (0x0080)
#define WDTPW               (0x5A00)


#define METADATA_ADDR 0x140
#define METADATA_SIZE 4 // 2-byte ERmin, 2-byte ERmax.
#define ERMIN_ADDR METADATA_ADDR
#define ERMAX_ADDR (ERMIN_ADDR + 2)

#define CHAL_ADDR 0x320
#define ATOKEN_CTRL (CHAL_ADDR + 32)

#define ENC_KEY_ADDR 0x360
#define CTR_ADDR (ENC_KEY_ADDR + 32)

#define BIT4 (0x0010)
#define HIGH 0x1
#define LOW 0x0

extern void pps_authenticate(); 
extern void my_memset(uint8_t* ptr, uint8_t val, size_t len);
extern void my_memcpy(uint8_t* dst, uint8_t* src, size_t size);

// Verifier gives this Atoken to the device to authorize application()
// For challenge with 11s
static uint8_t atoken[32] =   { 0x10, 0x12, 0x9f, 0x46, 0x21, 0xb4, 0x79, 0xe8, 0x4d, 0x0d, 0x16, 0x88, 0x23, 0xf1, 0xa2, 0xd4, 0xdc, 0x85, 0x52, 0x5a, 0xe8, 0x79, 0xe5, 0x86, 0x02, 0x73, 0x91, 0x6b, 0x91, 0xc7, 0x24, 0xe9 };


uint8_t application()
{
  // Read one byte information from GPIO: P3IN with a mask BIT4 
  // and encrypt it using first byte of encryption key derived by VERSA.
  // If atoken matches the application binary and given challenge,
  // this code executes successfully.
  return (P3IN & BIT4) ^ ((uint8_t) *((uint16_t*)ENC_KEY_ADDR));
}

int main() 
{
  // Switch off watch dog timer
  uint32_t* wdt = (uint32_t*)(WDTCTL_);
  *wdt = WDTPW | WDTHOLD;

  // Set the correct ER boundary values.
  *((uint16_t*)(ERMIN_ADDR)) = application;
  *((uint16_t*)(ERMAX_ADDR)) = my_memset - 2;

  // Accept the session challenge from the verifier and copy it to CHAL_ADDR.
  uint8_t *challenge = (uint8_t*)(CHAL_ADDR);
  my_memset(challenge, 0x11, 32);
  
  // Accept the AToken from the verifier and copy it to ATOKEN_CTRL.
  my_memcpy((uint8_t*)ATOKEN_CTRL, (uint8_t*)atoken, 32);

  // Authenicate app using the AToken received the verifier.
  pps_authenticate();

  // Call the application.
  application();

  __asm__ volatile("br #0xfffe" "\n\t");

  return 0;
}
