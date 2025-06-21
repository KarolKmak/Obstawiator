export function onRequest(context) {
   if (url.pathname === "/test")
   {
     return new Response("test");
   }
  return new Response("Hello, world!");
}
