FROM python:3.11-slim
COPY . /app
WORKDIR /app
RUN uv sync --all-extras --dev
CMD ["project_name"]
