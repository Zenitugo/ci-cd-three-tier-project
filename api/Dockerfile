# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.10.12
FROM python:${PYTHON_VERSION}-slim as base

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# ARG UID=10001
# RUN adduser \
#     --disabled-password \
#     --gecos "" \
#     --home "/nonexistent" \
#     --shell "/sbin/nologin" \
#     --no-create-home \
#     --uid "${UID}" \
#     appuser

# Copy the dependency file
COPY requirements.txt ./

# RUN --mount=type=cache,target=/root/.cache/pip \
#     --mount=type=bind,source=requirements.txt,target=requirements.txt \
#     python -m pip install -r requirements.txt


RUN pip install -r requirements.txt
# Switch to the non-privileged user to run the application.
# USER appuser


# Copy the source code into the container.
COPY . .

# # Use ARG to pass AWS credentials
# ARG AWS_ACCESS_KEY
# ARG AWS_SECRET_KEY
# ARG AWS_BUCKET_NAME

# # Export them as environment variables
# ENV AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY
# ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY
# ENV AWS_BUCKET_NAME=$AWS_BUCKET_NAME



# Expose the port that the application listens on.
EXPOSE 8000

# Run the application.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

