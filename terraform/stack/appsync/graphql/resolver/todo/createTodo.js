import { util } from "@aws-appsync/utils";
import * as ddb from "@aws-appsync/utils/dynamodb";

export function request(ctx) {
  const identity = ctx.identity;
  const now = util.time.nowISO8601();
  const id = ctx.args.input.id; // id is given by the client, no need to generate
  const input = ctx.args.input;

  const PK = `USER#${identity.sub}`;
  const SK = `TODO#${id}`;

  const item = {
    __typename: "Todo",
    PK,
    SK,
    id: input.id,
    owner: identity.sub,
    title: input.title,
    isCompleted: input.isCompleted ?? false,
    version: input.version ?? 0,
    createdAt: input.createdAt ?? now,
    updatedAt: input.updatedAt ?? now,
    isDeleted: input.isDeleted ?? false,
    syncStatus: input.syncStatus ?? "synced",
  };

  return ddb.put({
    key: { PK, SK },
    item,
  });
}

export function response(ctx) {
  if (ctx.error) util.error(ctx.error.message, ctx.error.type);
  const { PK, SK, __typename, ...todo } = ctx.result;
  return {
    ...todo,
    completed: todo.completed ?? todo.isCompleted ?? false,
    isCompleted: todo.completed ?? todo.isCompleted ?? false,
    version: todo.version ?? 0,
    isDeleted: todo.isDeleted ?? false,
    syncStatus: todo.syncStatus ?? "synced",
  };
}
