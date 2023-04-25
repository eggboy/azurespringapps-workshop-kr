이 섹션에서는 이전 섹션에서 배포한 백엔드 앱을 애플리케이션 구성 서비스 및 서비스 레지스트리에 바인딩하겠습니다.


다음은 Application Configuration Service 와 Service Registry 에 앱을 바인딩하는 다양한 단계입니다.
- [1. Create Application Configuration Service](#1-create-application-configuration-service)
  - [1.1. Configure apps to Application Configuration Service](#11-configure-apps-to-application-configuration-service)
- [2. Bind apps to Service Registry](#2-bind-apps-to-service-registry)


## 1. Create Application Configuration Service

계속해서 외부 위치에 저장된 구성으로 서비스를 가리키기 전에 먼저 해당 외부 리포지토리를 가리키는 Application Config Instance 를 만들어야 합니다. 이 경우 Azure CLI를 사용하여 GitHub 리포지토리를 가리키는 Application Config Instance를 만들겠습니다.

```shell
az spring application-configuration-service git repo add --name acme-fitness-store-config \
    --label main \
    --patterns "catalog/default,catalog/key-vault,identity/default,identity/key-vault,payment/default" \
    --uri "https://github.com/Azure-Samples/acme-fitness-store-config"
```

### 1.1. Configure apps to Application Configuration Service

이제 다음 단계는 위에서 만든 Application Configuration Service 인스턴스를 이 외부 구성을 사용하는 Azure 앱에 바인딩하는 것입니다:


```shell
az spring application-configuration-service bind --app payment-service

az spring application-configuration-service bind --app catalog-service
```

## 2. Bind apps to Service Registry

애플리케이션은 서로 통신해야 합니다. 워크샵에서 배운 것처럼, ASA-E는 내부적으로 동적 서비스 검색을 위해 Tanzu 서비스 레지스트리를 사용합니다. 이를 위해서는 아래 명령을 사용하여 필요한 서비스/애플리케이션을 서비스 레지스트리에 바인딩해야 합니다: 

```shell
az spring service-registry bind --app payment-service

az spring service-registry bind --app catalog-service
```

이번 섹션에서는 백엔드 앱을 Application Config Service 및 Service Registry 에 성공적으로 바인딩할 수 있었습니다.

⬅️ Previous guide: [04 - Hands On lab 3.1 - Deploy Backend apps](../04-hol-3.1-deploy-backend-apps/README.md)

➡️ Next guide: [06 - Hands On Lab 3.3 - Configure Database and Cache](../06-hol-3.3-configure-database-cache/README.md)