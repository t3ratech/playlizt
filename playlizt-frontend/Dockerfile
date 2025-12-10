# Stage 1: Serve with Nginx
FROM nginx:alpine

# Copy Nginx config if custom needed (optional, using default for now)
# COPY playlizt-frontend/nginx.conf /etc/nginx/conf.d/default.conf

# Copy build artifacts from host (Flutter web build)
COPY playlizt-frontend/playlizt_app/build/web /usr/share/nginx/html

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
