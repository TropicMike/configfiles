#!/bin/bash
echo "Stopping brcmfmac..."
sudo rmmod brcmfmac
echo "Sleeping 5 seconds..."
sleep 5
echo "Starting brcmfmac..."
sudo modprobe brcmfmac
sleep 5
