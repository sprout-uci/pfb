
import hmac
import hashlib 
import binascii
import time

def hmac_sha256(key, message):
    byte_key = binascii.unhexlify(key)
    message = message.decode("hex")
    return hmac.new(byte_key, message, hashlib.sha256).hexdigest().upper()

def reverse_endian(orig):
    return ''.join(sum([(c,d,a,b) for a,b,c,d in zip(*[iter(orig)]*4)], ()))

def swap_endianess(barray):

	for i in range(0, len(barray), 2):
		tmp = barray[i]
		barray[i] = barray[i+1]
		barray[i+1] = tmp
	return barray


def read_mem(filepath):
	out = []
	with open(filepath, 'r') as fp:
		lines = fp.readlines()
		for line in lines:
			if '@' not in line:
				continue
			mem = line.split()
			for i in range(1, len(mem)):
				out.extend(mem[i].decode('hex'))
	out = swap_endianess(out)
	out = bytearray(out)
	return out

key = "0123456789abcdef000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
chal = "1111111111111111111111111111111111111111111111111111111111111111"

pmem = read_mem('/home/sashi/senprivacy/privatesensor/msp_bin/pmem.mem')
ER_min = 0x08c
ER_max = 0x098 + 2
att_data = binascii.hexlify(pmem[ER_min:ER_max])

t = time.time()
dkey = hmac_sha256(reverse_endian(key), reverse_endian(chal))
token = hmac_sha256(dkey, att_data)

print("time taken for verifier to comupte atoken", time.time() - t)
print("size of ER:", ER_max - ER_min)

print("Key: ", key)
print("Chal: ", chal)
print("ER:", att_data)

dkey_list = []
i = 0
while (i < len(dkey)):
	dkey_list.append("0x{0}".format(dkey[i:i+2]))
	i += 2

print("DKey:", dkey)
print(', '.join(dkey_list).lower())

token_list = []
i = 0
while (i < len(token)):
	token_list.append("0x{0}".format(token[i:i+2]))
	i += 2

print("ATok:", token)
print(', '.join(token_list).lower())