FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["MerhumAPI/MerhumAPI.csproj", "MerhumAPI/"]
COPY ["MerhumContracts/MerhumContracts.csproj", "MerhumContracts/"]
RUN dotnet restore "MerhumAPI/MerhumAPI.csproj"
COPY . .
RUN dotnet build "MerhumAPI/MerhumAPI.csproj" -c $BUILD_CONFIGURATION -o /app/build /p:StaticWebAssetsEnabled=false

FROM build AS publish
RUN dotnet publish "MerhumAPI/MerhumAPI.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false /p:StaticWebAssetsEnabled=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
RUN mkdir -p /app/wwwroot/qrcodes /app/wwwroot/uploads/photos /app/wwwroot/uploads/profiles
ENTRYPOINT ["dotnet", "MerhumAPI.dll"]
