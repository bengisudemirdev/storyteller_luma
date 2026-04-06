declare module "swagger-ui-express" {
  import type { RequestHandler } from "express";

  export const serve: RequestHandler;
  export function setup(spec: unknown, options?: unknown): RequestHandler;

  const swaggerUi: {
    serve: RequestHandler;
    setup: (spec: unknown, options?: unknown) => RequestHandler;
  };

  export default swaggerUi;
}

