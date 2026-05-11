import { util } from "@aws-appsync/utils";
import * as ddb from "@aws-appsync/utils/dynamodb";

export function request(ctx) {
  const identity = ctx.identity;
  const input = ctx.args.input;
  const now = util.time.nowISO8601();

  const PK = `USER#${identity.sub}`;
  const SK = `TODO#${input.id}`;

  const update = {}; //object to hold the updates to be made to the todo
  if (input.title !== undefined) {
    update.title = input.title;
  }
  if (input.isCompleted !== undefined) {
    update.isCompleted = input.isCompleted;
  }
  if (input.version !== undefined) {
    update.version = input.version;
  }
  if (input.createdAt !== undefined) {
    update.createdAt = input.createdAt;
  }
  if (input.updatedAt !== undefined) {
    update.updatedAt = input.updatedAt;
  } else {
    update.updatedAt = now;
  }
  if (input.isDeleted !== undefined) {
    update.isDeleted = input.isDeleted;
  }
  if (input.syncStatus !== undefined) {
    update.syncStatus = input.syncStatus;
  }

  return ddb.update({ key: { PK, SK }, update });
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
