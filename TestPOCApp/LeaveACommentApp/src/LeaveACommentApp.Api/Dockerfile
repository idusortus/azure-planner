# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0-preview AS build
WORKDIR /src

# Copy csproj and restore
COPY src/LeaveACommentApp.Api/LeaveACommentApp.Api.csproj src/LeaveACommentApp.Api/
COPY LeaveACommentApp.ServiceDefaults/LeaveACommentApp.ServiceDefaults.csproj LeaveACommentApp.ServiceDefaults/
RUN dotnet restore src/LeaveACommentApp.Api/LeaveACommentApp.Api.csproj

# Copy everything and build
COPY src/LeaveACommentApp.Api/ src/LeaveACommentApp.Api/
COPY LeaveACommentApp.ServiceDefaults/ LeaveACommentApp.ServiceDefaults/
RUN dotnet publish src/LeaveACommentApp.Api/LeaveACommentApp.Api.csproj -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0-preview AS runtime
WORKDIR /app

# Copy published output
COPY --from=build /app/publish .

# Configure for Azure Container Apps
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "LeaveACommentApp.Api.dll"]
