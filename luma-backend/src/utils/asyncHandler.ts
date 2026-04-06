import type { NextFunction, Request, Response } from "express";

export type AsyncHandler<Req extends Request = Request, Res extends Response = Response> = (
  req: Req,
  res: Res,
  next: NextFunction
) => Promise<unknown>;

export function asyncHandler<Req extends Request = Request, Res extends Response = Response>(
  fn: AsyncHandler<Req, Res>
) {
  return (req: Req, res: Res, next: NextFunction) => {
    void Promise.resolve(fn(req, res, next)).catch(next);
  };
}

