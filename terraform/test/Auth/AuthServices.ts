import { Amplify } from "aws-amplify";
import { SignInOutput, fetchAuthSession, signIn } from "@aws-amplify/auth";
import { CognitoIdentityClient } from "@aws-sdk/client-cognito-identity";
import { fromCognitoIdentityPool } from "@aws-sdk/credential-providers";

// Updated values from @file_context_0 (1/1008-1013)
const USER_POOL_ID = "eu-west-2_apAXZPDOF";
const USER_POOL_CLIENT_ID = "6h0thj4thg08mbu5b4f7bqplf4";
// const IDENTITY_POOL_ID = ""; // Not provided in output, left blank
// const AWS_REGION = "eu-west-2";

Amplify.configure({
  Auth: {
    Cognito: {
      userPoolId: USER_POOL_ID,
      userPoolClientId: USER_POOL_CLIENT_ID,
    },
  },
});

export class AuthService {
  public async login(userName: string, password: string) {
    const signInOutput: SignInOutput = await signIn({
      username: userName,
      password: password,
      options: { authFlowType: "USER_SRP_AUTH" },

    });
    return signInOutput;
  }

  /**
   * call only after login
   */
  public async getIdToken() {
    const authSession = await fetchAuthSession();
    return authSession.tokens?.idToken?.toString();
  }
}
