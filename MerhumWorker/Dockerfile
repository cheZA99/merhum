FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["MerhumWorker/MerhumWorker.csproj", "MerhumWorker/"]
COPY ["MerhumContracts/MerhumContracts.csproj", "MerhumContracts/"]
RUN dotnet restore "MerhumWorker/MerhumWorker.csproj"
COPY . .
RUN dotnet build "MerhumWorker/MerhumWorker.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
RUN dotnet publish "MerhumWorker/MerhumWorker.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MerhumWorker.dll"]
