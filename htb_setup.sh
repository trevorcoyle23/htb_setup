#!/bin/bash

# htb_setup.sh
#
# Root HTB:
#   - The root qdisc specifies the maximum bandwidth
#     of the interface as 1000 Mbps.
#
# Classes:
#   * Class 1:10 (source port 80):
#       - Guaranteed minimum rate of 80 Mbps ('rate').
#       - Maximum burstable rate of 200 Mbps ('ceil').
#       - Priority 1 (lower priority than 'prio 0').
#   * Class 1:20 (all other traffic):
#       - Guaranteed minimum rate of 200 Mbps.
#       - Maximum burstable rate of 1000 Mbps.
#       - Priority 0 (higher priority).
# 
# sfq Disciplines:
#   - Adds a stochastic fainess queue to both
#     child classes.
#   - Ensures fairness within each class and 
#     perturbs the hash every 10 seconds to 
#     avoid bias.
#
# Filters:
#   * Classify packets into their respective classes.
#       - Traffic with source port 80 is matched
#         using 'u32' and directed to class 1:10.
#       - All other traffic is directed to class
#         1:20.

# Interface where traffic control is applied (adjust as needed)
INTERFACE="ens192"

# Clear any existing qdisc configuration
tc qdisc del dev $INTERFACE root 2>/dev/null

# Step 1: Add the root HTB qdisc with a maximum bandwidth of 1000 Mbps
tc qdisc add dev $INTERFACE root handle 1: htb default 20

# Step 2: Add two HTB classes:
#   Class 10: Traffic with source port 80
tc class add dev $INTERFACE parent 1: classid 1:10 htb rate 80mbit ceil 200mbit prio 1

#   Class 20: All other traffic
tc class add dev $INTERFACE parent 1: classid 1:20 htb rate 200mbit ceil 1000mbit prio 0

# Step 3: Attach an sfq discipline to both classes with a perturbation interval of 10 seconds
tc qdisc add dev $INTERFACE parent 1:10 handle 10: sfq perturb 10
tc qdisc add dev $INTERFACE parent 1:20 handle 20: sfq perturb 10

# Step 4: Add filters to classify traffic into the appropriate classes
#    Traffic with source port 80 -> Class 10
tc filter add dev $INTERFACE protocol ip parent 1: prio 1 u32 match ip sport 80 0xffff flowid 1:10

#    All other traffic           -> Class 20
tc filter add dev $INTERFACE protocol ip parent 1: prio 2 u32 match ip protocol 0 0x00 flowid 1:20
