# Recommended server-side embedding for VERIFY / FORGET / INVITE tokens

Do **not** interpolate tokens into JS with partial HTML escaping.
Use JSON encoding so `\`, quotes, newlines, and U+2028/U+2029 cannot break out.

```csharp
// Example ASP.NET Core snippet (adapt to actual stack)
var token = Request.Query["token"].ToString();
var safe = System.Text.Json.JsonSerializer.Serialize(token); // includes surrounding quotes
var loginUrl = "https://mein.wien.gv.at/login/?first=1&type=Handy-Signatur";
var safeUrl = System.Text.Json.JsonSerializer.Serialize(loginUrl);

// Razor / template:
// <script>
//   window.VERIFY = { token: @Html.Raw(safe), url: @Html.Raw(safeUrl) };
// </script>
```

```js
// Equivalent Node/Express view helper
const payload = JSON.stringify({
  token: String(req.query.token || ""),
  url: "https://mein.wien.gv.at/login/?first=1&type=Handy-Signatur",
});
res.send(`<script>window.VERIFY = ${payload};</script>`);
```

Prefer **not** putting activation secrets in URLs at all:

1. Email link → `GET /Verifizierung/start?sid=<opaque-session>` (non-secret).
2. Server looks up one-time secret server-side, marks single-use, activates.
3. Or email contains a form POST one-time code.

Also remove `/Verifizierung` from any third-party Universal Links claim (see `apple-app-site-association.fixed.json`).
