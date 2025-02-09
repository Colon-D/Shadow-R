extends Node

# This is the *only* thing I have decompiled from Sonic R, because it was
# simple enough.
# The Powerup choosing logic is in the function at 0x429CA0.
# Sonic R has five tables, at (0x45E1C8 + Place * 0x14), where Place is [1, 5].
#   Each table is 20 bytes long, with each byte being a powerup.
# This table is sampled at random. There is bias against the final:
#   RNG seems to be a table at 0x502170, with a length of 256.
#   It is iterated through, and then looped.
#   It has a uniform distribution of values [0x0, 0xFF] in a random order.
#   (I don't know that this is correct, but it looks correct with my eyes)
#   The index into the powerup table is the RNG value / 0xD, truncated down.
#   Since 0xFF / 0xD = 19.61..., index 19 is 39% less likely to be chosen.
# There is some unknown condition that will replace Water Shield or Lightning
# Shield with 20 Rings instead. I'm going to ignore it for now.
# Here is the value each powerup has:
#   Fleet Feet: 1
#   5 Rings: 2
#   10 Rings: 3
#   20 Rings: 4
#   Water Sheild: 5
#   Lightning Shield: 6
# Here are the tables for each place:
#   1st Place: 2 2 2 2 2 2 2 2 2 2 3 3 3 3 3 3 4 5 5 6
#   2nd Place: 1 1 2 2 2 2 2 2 2 2 3 3 3 3 4 4 5 5 6 6
#   3rd Place: 1 1 1 1 2 2 2 2 2 2 3 3 3 3 4 4 5 5 6 6
#   4th Place: 1 1 1 1 1 1 1 1 2 3 3 4 4 4 4 4 6 6 6 6
#   5th Place: 1 1 1 1 1 1 1 1 1 1 4 4 4 4 4 4 6 6 6 6
# It will probably be easiest to ignore the bias against the final powerup.
# No-one will notice, except for you because you are reading my source code.
# I'm sorry for making you read such garbage :(