FROM python:alpine AS build

WORKDIR /app
COPY . .
RUN pip install -r requirements.txt

USER nobody
CMD python app.py

EXPOSE 3000