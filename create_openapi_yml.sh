#!/bin/sh

# Create openapi.yml from AppMaps
npx @appland/appmap openapi --output-file openapi.yml --openapi-title 'Forem API V1' --openapi-version '1.0.0'
