#!/bin/bash
yum update -y
yum install -y nginx 
yum install -y java-1.8.0-amazon-corretto.x86_64
systemctl enable nginx
systemctl start nginx
