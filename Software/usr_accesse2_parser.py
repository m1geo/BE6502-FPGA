# Quick python script to parse USR_ACCESSE2 string
# See Xilinx AppNote XAPP497 (https://docs.amd.com/v/u/en-US/xapp497_usr_access)
# George Smart, M1GEO
# V1.0; 26-Oct-2024
#
# Minimal error checking. Fully untested :)
# For BE6502 computer, argv[1] should be the output of "7020.7023" in the little endian format.

## From XAPP497
#
# BitGen inserts the current timestamp into the 32-bit USR_ACCESS register in this format:
#  ddddd_MMMM_yyyyyy_hhhhh_mmmmmm_ssssss
# (bit 31) ……………………………………………………..… (bit 0)
#
# Where:
#   dddddd = 5 bits to represent 31 days in a month
#   MMMM = 4 bits to represent 12 month in a year
#   yyyyyy = 6 bits to represent 0 to 63 (to note year 2000 to 2063)
#   hhhhh = 5 bits to represent 23 hours in a day
#   mmmmmm = 6 bits to represent 59 minutes in an hour
#   ssssss = 6 bits to represent 59 seconds in a minute
#

# Import sys lib for arvg
import sys

# Read and check input
try:
  supplied_str = sys.argv[1]
except:
  print("Failed to parse command line argument. Please try:\n")
  print("\t%s \"AABBCCDD\"" % sys.argv[0])
  print("or")
  print("\t%s \"AA BB CC DD\"" % sys.argv[0])
  print("Exiting.")
  exit(-1)

# Check if the string was a standard 32b number or the Wozmon UART format
if " " in supplied_str:
  print("Input in Wozmon UART format") # Assuming little endian Wozmon format
  splitup = supplied_str.split()
  if len(splitup) != 4:
    print("Expecting 4 separate bytes in UART format: '%s'" % supplied_str)
    exit(-1)
  rev_str = splitup[3] + splitup[2] + splitup[1] + splitup[0] # values are strings, so expecting concat() not arithemtic addition
  std_fmt = int(rev_str, 16)
else: # Assume here it's just a hex number parsable by int(x,16)
  print("Input in standard format")
  try:
    std_fmt = int(supplied_str, 16)
  except:
    std_fmt = -1

# Check the converstion resulted in something sane (here, just > 0)
if std_fmt < 0:
  print("Couldn't parse '%s'. Sorry." % supplied_str)
  print("Exiting.")
  exit(-1)

print("Understood 0x%lX" % (std_fmt))

## Think we have the number in a standard hex format by here, parse it:

# Verbosely expose everything, as it's easier to check
usr_sc = (std_fmt & (0b111111 << 0)) >> 0 # 6b
usr_mi = (std_fmt & (0b111111 << 6)) >> 6 # 6b
usr_hr = (std_fmt &  (0b11111 << 12)) >> (6+6) # 5b
usr_yr = ((std_fmt & (0b111111 << 17)) >> (6+6+5)) + 2000 # 6b
usr_mo = (std_fmt &   (0b1111 << 23)) >> (6+6+5+6) # 4b
usr_da = (std_fmt & (0b111111 << 27)) >> (6+6+5+6+4) # 5b

# Show each output
#print("usr_sc : %u" % usr_sc)
#print("usr_mi : %u" % usr_mi)
#print("usr_hr : %u" % usr_hr)
#print("usr_yr : %u" % usr_yr)
#print("usr_mo : %u" % usr_mo)
#print("usr_da : %u" % usr_da)

# Make a nice format
builddate = "%02u/%02u/%04u" % (usr_da, usr_mo, usr_yr)
buildtime = "%02u:%02u:%02u" % (usr_hr, usr_mi, usr_sc)

# Show the user
print("Build Date: %s (dd/mm/yy)" % builddate)
print("Build Time: %s" % buildtime)

exit(0)
