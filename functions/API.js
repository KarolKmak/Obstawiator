export function onRequest(context) {
   const url = new URL(context.request.url);
   if (url.pathname === "/test")
   {
     return new Response("test");
   }
  return new Response("Hello, world!");
}
