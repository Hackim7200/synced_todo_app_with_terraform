const String amplifyconfig = '''
{
  "version": "1",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/0.1.0",
        "Version": "0.1.0",
        "CognitoUserPool": {
          "Default": {
            "PoolId": "eu-west-2_apAXZPDOF",
            "AppClientId": "6h0thj4thg08mbu5b4f7bqplf4",
            "Region": "eu-west-2"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH",
            "usernameAttributes": ["EMAIL"],
            "signupAttributes": ["EMAIL"],
            "passwordProtectionSettings": {
              "passwordPolicyMinLength": 8,
              "passwordPolicyCharacters": [
                "REQUIRES_LOWERCASE",
                "REQUIRES_UPPERCASE",
                "REQUIRES_NUMBERS"
              ]
            }
          }
        }
      }
    }
  },
  "api": {
    "plugins": {
      "awsAPIPlugin": {
        "PomodoroPlansGraphQLApi": {
          "endpointType": "GraphQL",
          "endpoint": "https://a2zjdhfftvfvznek67g6hrub2q.appsync-api.eu-west-2.amazonaws.com/graphql",
          "region": "eu-west-2",
          "authorizationType": "AMAZON_COGNITO_USER_POOLS"
        }
      }
    }
  }
}
''';
// datastack is not added here since its accessed via lambda apigateway