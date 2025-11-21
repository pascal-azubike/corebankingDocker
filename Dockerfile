# ===== Base image =====
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 5001

# Install curl for health check
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# ===== Build image =====
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy only the project file first (for caching)
COPY ["src/WebApplication.csproj", "src/"]

# Restore dependencies
RUN dotnet restore "src/WebApplication.csproj"

# Copy the full source code
COPY . .

# Build the project
WORKDIR "/src/src"
RUN dotnet build "WebApplication.csproj" -c Release -o /app/build

# ===== Publish image =====
FROM build AS publish
RUN dotnet publish "WebApplication.csproj" -c Release -o /app/publish /p:UseAppHost=false

# ===== Final runtime image =====
FROM base AS final
WORKDIR /app

# Copy published output
COPY --from=publish /app/publish .

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser \
    && chown -R appuser:appuser /app
USER appuser

# Healthcheck on HTTP port
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:80/health || exit 1

ENTRYPOINT ["dotnet", "WebApplication.dll"]
