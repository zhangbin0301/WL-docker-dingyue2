FROM daxia2023/doc:sub2

ENV PORT=8080

EXPOSE ${PORT}
    
WORKDIR /app

COPY . .

RUN apk update \
    && apk add --no-cache bash curl unzip nginx iproute2 jq gawk git \
    && chmod +x ./entrypoint.sh \
    && rm -rf /var/lib/apt/lists/*
CMD [ "/app/entrypoint.sh" ]
