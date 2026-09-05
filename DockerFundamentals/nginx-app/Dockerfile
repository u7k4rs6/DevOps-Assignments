FROM nginx:alpine

# nginx's default web root - dropping a file here is all it takes
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
# The base image already sets a correct CMD (nginx -g 'daemon off;'),
# so overriding it would only risk getting it wrong.
