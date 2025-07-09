# 1단계: React 앱 빌드
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# 2단계: 빌드된 정적 파일을 Nginx로 서비스
FROM nginx:stable-alpine

# React에서 생성된 빌드 파일을 Nginx 기본 경로로 복사
COPY --from=builder /app/build /usr/share/nginx/html

# Nginx 포트 열기
EXPOSE 80

# 기본 명령어
CMD ["nginx", "-g", "daemon off;"]
