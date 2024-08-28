#!/bin/bash

multipass stop kubeworker02
multipass stop kubeworker01
multipass stop kubemaster

multipass snapshot kubemaster
multipass snapshot kubeworker01
multipass snapshot kubeworker02

multipass list --snapshots

multipass restore kubemaster.snapshot1
multipass restore kubeworker01.snapshot1
multipass restore kubeworker02.snapshot1