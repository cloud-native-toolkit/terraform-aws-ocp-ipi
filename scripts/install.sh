#!/usr/bin/env bash

cd $INSTALL_PATH
${BINARY_PATH}/openshift-install create cluster --dir ./
