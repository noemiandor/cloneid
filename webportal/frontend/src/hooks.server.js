
export const handle = async ({ resolve, event }) => {
    // console.log("EVENT", event)

    // Apply CORS header for API routes
    //   if (event.url.pathname.startsWith('/api')) {
    // Required for CORS to work
    if (event.request.method === 'OPTIONS') {
        console.log("EVENT", event)
        return new Response(null, {
            headers: {
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': '*',
            }
        });
    }

    //   }

    const response = await resolve(event);
    // console.log("RESPONSE", response, event)
    //   if (event.url.pathname.startsWith('/api')) {
    response.headers.append('Access-Control-Allow-Origin', '*');
    response.headers.append('Access-Control-Allow-Headers', `*`);
    //   }
    return response;
}
