#!/bin/bash

eval "$(GIMME_GO_VERSION=1.8.3 gimme)"
go get github.com/pulumi/travisqueue
travisqueue start
