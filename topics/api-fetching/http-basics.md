# HTTP Basics for Frontend Developers

- **Abstraction level**: protocol
- **Category**: networking

## Related Topics

- **Depends on this**: REST
- **Depends on this**: API design
- **Works alongside**: JSON
- **Works alongside**: caching
- **Contrast with**: WebSocket
- **Contrast with**: TCP
- **Temporal neighbors**: browser request lifecycle
- **Temporal neighbors**: authentication on the web

## What is it

HTTP is the standard set of rules that browsers and servers use to exchange web data. It defines how a client asks for something, how a server answers, and how both sides describe the meaning of that data. For frontend developers, HTTP is the protocol behind loading pages, calling APIs, sending form data, uploading files, and receiving errors.

The data is usually text or binary content such as HTML, JSON, images, or files. It moves across the network between a client, usually the browser, and a server. The browser writes requests, the server writes responses, and each exchange changes over time as new requests are made for different resources or actions.

## What problem does it solve

Start with a simple case: a browser wants a page. The browser needs a way to ask for `/about`, and the server needs a way to answer with the page data. That already requires agreement on where the data is, what format it is in, and whether the request succeeded.

Now add more complexity. A page loads user data, posts a comment, downloads an image, and retries after a failure. Different servers, browsers, and teams all need to understand the same messages. Without a shared protocol, every application would invent its own message format and its own meaning for success, failure, identity, and content type.

What goes wrong without HTTP:

- Duplication: every client and server pair would need custom rules.
- Inconsistency: one endpoint might use `ok`, another might use `done`, another might return nothing.
- Invalid data: the client would not know whether bytes represent JSON, HTML, or an image.
- Hard-to-track changes: failures and retries would have no standard meaning.
- Unclear ownership: the client would not know what it controls and what the server controls.

## How does it solve it

### 1. Request and response

HTTP turns communication into a predictable flow: client sends a request, server sends a response. The request says what the client wants; the response says what the server has or what happened. This makes data flow explicit and easy to reason about.

### 2. Resource addressing with URLs

A URL identifies the target of the request. It tells the server which resource or action the client is talking about, such as `/products/42` or `/search?q=shoes`. This gives clear control over where data lives.

### 3. Methods describe intent

HTTP methods like `GET`, `POST`, `PUT`, `PATCH`, and `DELETE` tell the server what kind of change is being requested. A `GET` usually asks to read data; a `POST` usually creates or submits data. This makes state transitions more explicit than sending an untyped message.

### 4. Headers describe metadata

Headers carry information about the message instead of the main data itself. They can say what format the body uses, whether the client accepts JSON, whether the response can be cached, or who the user is. This separates content from control information.

### 5. Body carries the main payload

The body contains the actual data being transferred when needed. That might be JSON for an API, HTML for a page, or binary bytes for a file upload. This keeps transformation clear: metadata stays in headers, core data stays in the body.

### 6. Status codes standardize outcomes

The response includes a status code such as `200`, `201`, `404`, or `500`. That gives the client a shared language for success, missing data, invalid requests, and server failures. Correctness becomes easier to check because valid and invalid outcomes are classified explicitly.

### 7. Stateless communication

Each HTTP request is self-contained. The server should be able to understand it from the data in that request, without relying on hidden memory of previous requests. This improves scalability and predictability, even though extra mechanisms like cookies or tokens may still carry user context.

## What if we didn't have it (Alternatives)

### 1. Simple manual approach

```text
client -> "give me user 42"
server -> "here"
```

This works only if both sides already share many unwritten rules. At scale, it breaks because there is no standard meaning for errors, data format, or version changes.

### 2. Everything in one custom text format

```text
SEND|USER|42|AUTH=yes
OK|name=Ana
```

This is a quick hack version of a protocol. It creates hidden coupling because every client and server must parse the same custom string rules exactly.

### 3. Put all data in the URL

```text
/createUser?name=Ana&role=admin&bio=very-long-text...
```

This becomes hard to validate and hard to evolve. URLs are good for identifying resources and small query data, not for every kind of payload.

### 4. Infer success from the body only

```json
{ "message": "something happened" }
```

Without a standard status code, the client has to guess whether this means success, failure, partial success, or an unexpected state.

## Examples

### 1. Minimal conceptual example

The browser asks for a page:

```text
GET /about
```

The server answers with page data:

```text
200 OK + HTML body
```

The main idea is simple: request asks, response answers.

### 2. Reading data without changing it

```http
GET /users/42
Accept: application/json
```

```http
200 OK
Content-Type: application/json
```

The client is asking to read existing data. No server state should change just because this request happened.

### 3. Sending new data to the server

```http
POST /comments
Content-Type: application/json

{ "text": "Nice article" }
```

```http
201 Created
```

Here the body carries new data, and the response says a new resource was created. This is a state change on the server.

### 4. Incorrect vs correct handling of missing data

Incorrect:

```http
GET /products/9999
200 OK
```

Correct:

```http
GET /products/9999
404 Not Found
```

The second version is better because correctness is explicit. The client can react differently to "missing" than to "success."

### 5. Real-world analogy

HTTP is like a form with fixed fields:

- URL: which department you are contacting
- Method: what you want done
- Headers: instructions and metadata
- Body: the actual content
- Status code: the official result

The value is not the paper form itself; the value is that everyone reads it the same way.

### 6. Browser and server interaction

A product page opens and the browser makes several HTTP requests over time:

1. `GET /products/42` for product data
2. `GET /images/42.jpg` for the image
3. `POST /cart/items` when the user clicks "Add to cart"

Each request has a different purpose, different data, and possibly a different state change. HTTP keeps those changes separate and predictable.

### 7. Headers vs body

```http
POST /upload
Content-Type: image/png
Authorization: Bearer <token>

<binary file bytes>
```

The headers tell the server how to interpret and authorize the request. The body contains the actual file data.

## Quickfire (Interview Q&A)

### 1. What is HTTP?

It is a protocol for client-server communication on the web. It defines how requests and responses are structured and interpreted.

### 2. Why does a frontend developer need HTTP?

Frontend code constantly reads and sends data through HTTP. Understanding it helps you reason about loading, errors, caching, and API behavior.

### 3. What is the difference between a request and a response?

A request is sent by the client to ask for or submit data. A response is sent by the server to return data or report the outcome.

### 4. What does an HTTP method represent?

It represents the intended action, such as reading, creating, updating, or deleting data. It gives meaning to how a request should affect server state.

### 5. What is the role of headers?

Headers carry metadata about the message. They describe format, caching rules, authorization, and other control information.

### 6. What is the role of the body?

The body contains the main payload when a message needs one. It is where the actual resource data or submitted input usually lives.

### 7. Why are status codes useful?

They give a standard, machine-readable meaning to the result. The client can handle success, client errors, and server errors differently.

### 8. What does stateless mean in HTTP?

Each request should contain enough information to be understood on its own. The server should not depend on hidden request history to interpret it.

### 9. Is HTTP only for JSON APIs?

No. HTTP can carry HTML, JSON, images, files, CSS, JavaScript, and other content types.

### 10. What is the difference between HTTP and WebSocket?

HTTP is typically request-response based. WebSocket is designed for long-lived, two-way communication after the connection is established.

## Key Takeaways

- HTTP is just a standard way to control how web data moves between client and server.
- A request says what the client wants; a response says what happened.
- URL, method, headers, body, and status code each have a separate job.
- Methods help express intended state changes.
- Status codes make success and failure explicit.
- Headers describe the message; the body carries the main data.
- Statelessness improves predictability and scalability.

## Vocabulary

### Nouns (concepts)

- **HTTP**: A web communication protocol. It defines the structure and meaning of requests and responses.
- **client**: The side that starts a request, usually the browser in frontend work. It asks for data or sends user actions.
- **server**: The side that receives requests and sends responses. It owns resources and applies business rules.
- **request**: A message from client to server. It includes the target, intent, metadata, and sometimes a body.
- **response**: A message from server to client. It includes the outcome and often returns data.
- **URL**: The address of the target resource or endpoint. It tells the server what the request is about.
- **resource**: A thing exposed over HTTP, such as a page, image, user record, or collection of comments.
- **method**: The request verb, such as `GET` or `POST`. It signals the intended operation.
- **header**: A metadata field in a request or response. It helps both sides interpret and control the message.
- **body**: The main payload of a message. It carries the actual content being sent.
- **status code**: A numeric result code in the response. It standardizes outcomes like success, missing data, or server failure.
- **payload**: The actual data being transferred. In HTTP, it is usually in the body.
- **content type**: A label that describes the data format, such as `application/json` or `text/html`. It tells the receiver how to parse the body.
- **endpoint**: A server URL that accepts a certain kind of request. Frontend developers often call APIs through endpoints.

### Verbs (actions)

- **request**: To ask a server for data or an action. This starts the HTTP exchange.
- **respond**: To send the result of a request back to the client. The server does this with a status code, headers, and optional body.
- **send**: To transmit data across the network. Both client and server send HTTP messages.
- **receive**: To accept and read an incoming HTTP message. Correct handling depends on format and status.
- **fetch**: To retrieve data from a server. In interviews, this usually means making an HTTP request from the client.
- **submit**: To send user-provided data to the server. This is common with forms and create/update actions.
- **validate**: To check whether incoming data is acceptable. Servers validate request data; clients often validate before sending too.
- **parse**: To convert raw message data into a usable structure. For example, reading JSON from a response body.

### Adjectives (properties)

- **stateless**: Each request stands on its own. This is a core property of HTTP communication.
- **predictable**: Easy to reason about because the message structure and outcomes are standardized. HTTP aims for this.
- **valid**: Data that matches expected rules or format. HTTP supports validation through content types, status codes, and server checks.
- **invalid**: Data that is malformed, missing required fields, or otherwise unacceptable. Good HTTP design makes invalid cases explicit.
- **cacheable**: Safe or useful to store and reuse temporarily instead of requesting again immediately. Some HTTP responses are designed for this.
