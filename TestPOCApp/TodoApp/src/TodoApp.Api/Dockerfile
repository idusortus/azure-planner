# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy csproj files and restore
COPY ["src/TodoApp.Api/TodoApp.Api.csproj", "src/TodoApp.Api/"]
COPY ["TodoApp.ServiceDefaults/TodoApp.ServiceDefaults.csproj", "TodoApp.ServiceDefaults/"]
RUN dotnet restore "src/TodoApp.Api/TodoApp.Api.csproj"

# Copy everything else and build
COPY ["src/TodoApp.Api/", "src/TodoApp.Api/"]
COPY ["TodoApp.ServiceDefaults/", "TodoApp.ServiceDefaults/"]
RUN dotnet build "src/TodoApp.Api/TodoApp.Api.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "src/TodoApp.Api/TodoApp.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# Copy published app
COPY --from=publish /app/publish .

ENTRYPOINT ["dotnet", "TodoApp.Api.dll"]
