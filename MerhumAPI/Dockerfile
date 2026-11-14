FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["MerhumAPI/MerhumAPI.csproj", "MerhumAPI/"]
COPY ["MerhumContracts/MerhumContracts.csproj", "MerhumContracts/"]
RUN dotnet restore "MerhumAPI/MerhumAPI.csproj"
COPY MerhumContracts/ MerhumContracts/
COPY MerhumAPI/ MerhumAPI/
RUN dotnet publish "MerhumAPI/MerhumAPI.csproj" -c $BUILD_CONFIGURATION -o /app/publish --no-restore /p:UseAppHost=false /p:StaticWebAssetsEnabled=false

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
# the trained model.zip is written next to the binaries and uploads go to wwwroot
RUN mkdir -p wwwroot/qrcodes wwwroot/uploads/photos wwwroot/uploads/profiles \
    && chown "$APP_UID" /app \
    && chown -R "$APP_UID" /app/wwwroot
USER $APP_UID
ENTRYPOINT ["dotnet", "MerhumAPI.dll"]
