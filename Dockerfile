# Этап 1: Сборка приложения
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /app

# Копируем файлы решения и проекты
COPY *.sln .
COPY Directory.Build.props .
COPY Directory.Packages.props .
COPY nuget.config .
COPY src/AppServices/ src/AppServices/
COPY src/Domain/ src/Domain/
COPY src/EfRepository/ src/EfRepository/
COPY src/LocalRepository/ src/LocalRepository/
COPY src/TestData/ src/TestData/
COPY src/WebApp/ src/WebApp/

# Печатаем содержимое директории, чтобы проверить, что файл существует
RUN ls -al src/WebApp

# Создадим файл appsettings.Development.json через echo с экранированными кавычками
RUN echo "{\"DevSettings\": {\"UseDevSettings\": true, \"UseInMemoryData\": true, \"UseEfMigrations\": false, \"DeleteAndRebuildDatabase\": true, \"UseAzureAd\": false, \"LocalUserIsAuthenticated\": true, \"LocalUserRoles\": [], \"UseSecurityHeadersInDev\": false, \"EnableWebOptimizer\": false}}" > /app/appsettings.Development.json

# Копируем настройки в корень контейнера
COPY src/WebApp/appsettings.json /app/appsettings.json

WORKDIR /app/src/WebApp
RUN dotnet restore

# Компилируем и публикуем приложение
RUN dotnet publish -c Debug -o /app/publish

# Этап 2: Создание итогового образа
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Development
EXPOSE 8080
ENTRYPOINT ["dotnet", "WebApp.dll"]
