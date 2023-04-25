이 단원에서는 Azure Active Directory 또는 다른 ID Provider를 사용하여 Spring 클라우드 게이트웨이용 Single Sign-On을 구성합니다.

이 섹션이 완료되면 다음과 같이 아키텍처가 구성됩니다:
![architecture](images/scg-sso-services.png) 

## 1. Register Application with Azure AD

애플리케이션 등록을 위한 고유한 Display 이름을 선택하세요.

```shell
export AD_DISPLAY_NAME=acme-ad-YOUR-UNIQUE_USERNAME    # unique application display name
```

Azure AD에서 애플리케이션을 등록하고 출력을 저장합니다.

```shell
az ad app create --display-name ${AD_DISPLAY_NAME} > ad.json
```

Application ID 를 검색해서 client secret 을 저장합니다:

```shell
export APPLICATION_ID=$(cat ad.json | jq -r '.appId')

az ad app credential reset --id ${APPLICATION_ID} --append > sso.json
```

Azure AD 애플리케이션 등록에 필요한 웹 리디렉션 URI를 추가합니다:

```shell
az ad app update --id ${APPLICATION_ID} \
    --web-redirect-uris "https://${GATEWAY_URL}/login/oauth2/code/sso" \
     "https://${PORTAL_URL}/oauth2-redirect.html" "https://${PORTAL_URL}/login/oauth2/code/sso"
```

리다이렉트 URI 에 대한 자세한 정보는 다음에 링크에서 확인하실 수 있습니다 [here](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app#add-a-redirect-uri).

Service Principal 을 해당 어플리케이션에 등록 합니다.

```shell
az ad sp create --id ${APPLICATION_ID}
```

어플리케이션 등록에 대한 자세한 정보는 다음에 링크에서 확인하실 수 있습니다 [here](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)

### 1.1. Prepare your environment for SSO Deployments

제공된 스크립트를 사용하여 환경을 설정하고 환경 변수가 설정되었는지 확인합니다:

```shell
source ./scripts/setup-sso-variables-ad.sh

echo ${CLIENT_ID}
echo ${CLIENT_SECRET}
echo ${TENANT_ID}
echo ${ISSUER_URI}
echo ${JWK_SET_URI}
```

 `ISSUER_URI` 형식은 다음과 같습니다 `https://login.microsoftonline.com/${TENANT_ID}/v2.0`
 `JWK_SET_URI` 형식은 다음과 같습니다 `https://login.microsoftonline.com/${TENANT_ID}/discovery/v2.0/keys`

## 2. Create and Deploy the Identity Service Application

Identity 서비스 어플리케이션을 생성합니다

```shell
az spring app create --name ${IDENTITY_SERVICE_APP} --instance-count 1 --memory 1Gi
```

Identity 서비스를 Application Configuration Service 에 바인딩 합니다.

```shell
az spring application-configuration-service bind --app ${IDENTITY_SERVICE_APP}
```

Identity 서비스를 Service Registry 에 바인딩 합니다.

```shell
az spring service-registry bind --app ${IDENTITY_SERVICE_APP}
```

Identity 서비스를 위한 라우팅 룰을 SCG 에 등록합니다.

```shell
az spring gateway route-config create \
    --name ${IDENTITY_SERVICE_APP} \
    --app-name ${IDENTITY_SERVICE_APP} \
    --routes-file ./routes/identity-service.json
```

### 2.1. Deploy the Identity Service:

```shell
az spring app deploy --name ${IDENTITY_SERVICE_APP} \
    --env "JWK_URI=${JWK_SET_URI}" \
    --config-file-pattern identity/default \
    --build-env BP_JVM_VERSION=17 \
    --source-path ./apps/acme-identity
```

> Note: 애플리케이션을 배포하는 데 약 3~5분이 소요됩니다.

## 3. Configure Spring Cloud Gateway with SSO

Spring Cloud Gateway 에 SSO를 활성화합니다:

```shell
az spring gateway update \
    --client-id ${CLIENT_ID} \
    --client-secret ${CLIENT_SECRET} \
    --scope ${SCOPE} \
    --issuer-uri ${ISSUER_URI} \
    --no-wait
```

### 3.1. Update Existing Applications

기존 애플리케이션이 Spring Cloud Gateway의 인증 정보를 사용하도록 업데이트합니다:

```shell
# Update the Cart Service
az spring app update --name ${CART_SERVICE_APP} \
    --env "AUTH_URL=https://${GATEWAY_URL}" "CART_PORT=8080" 
    
# Update the Order Service
az spring app  update --name ${ORDER_SERVICE_APP} \
    --env "AcmeServiceSettings__AuthUrl=https://${GATEWAY_URL}" 
```

### 3.2. Login to the Application through Spring Cloud Gateway

Spring Cloud Gateway의 URL을 검색하여 브라우저에서 엽니다:

```shell
echo "https://${GATEWAY_URL}"
```

ACME 피트니스 스토어 애플리케이션이 표시되고 SSO를 사용하여 로그인할 수 있어야 하며 애플리케이션의 나머지 기능을 사용할 수 있습니다. 장바구니에 품목을 추가하고 주문하는 것이 모두 포함됩니다.

## 4. Configure SSO for API Portal

API Portal 을 위한 SSO 를 구성합니다:

```shell
export PORTAL_URL=$(az spring api-portal show | jq -r '.properties.url')

az spring api-portal update \
    --client-id ${CLIENT_ID} \
    --client-secret ${CLIENT_SECRET}\
    --scope "openid,profile,email" \
    --issuer-uri ${ISSUER_URI}
```

### 4.1. Explore the API using API Portal

브라우저에서 API 포털을 열면 지금부터는 로그인을하도록 리디렉션됩니다:

```shell
echo "https://${PORTAL_URL}"
```

보호된 API에 액세스하려면 Authorize 를 클릭하고 SSO Provider 에 맞는 단계를 따르세요. API 포털을 통한 API 인증에 대해서 자세히 알아보려면 다음에 링크를 클릭하세요 [here](https://docs.vmware.com/en/API-portal-for-VMware-Tanzu/1.0/api-portal/GUID-api-viewer.html#api-authorization)

## 5. Testing the app

이제 앱 테스트를 시작하고 주문할 준비가 모두 완료되었습니다.

이제 주문을 수행하여 주문 데이터가 PostgreSQL 데이터베이스에 저장되는지 확인합니다. 다음 URL로 주문 내역을 확인합니다.:

```text
echo https://${GATEWAY_URL}/order/${USER_ID}
```

USER_ID는 URL로 인코딩된 문자열로서의 사용자 이름입니다. 예를 들어: John Smith는 John%20Smith입니다.


⬅️ Previous guide: [06 - Hands On Lab 3.3 - Configure Database and Cache](../06-hol-3.3-configure-database-cache/README.md)

➡️ Next guide: [08 - Hands On Lab 3.5 - Configure Azure KeyVault](../08-hol-3.5-configure-azure-keyvault/README.md)