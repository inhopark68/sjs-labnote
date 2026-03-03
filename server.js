const express = require("express");
const path = require("path");

const app = express();
const webDir = path.join(__dirname, "build", "web");

// ✅ Cross-Origin Isolation 헤더 (SharedArrayBuffer/OPFS 안정화)
app.use((req, res, next) => {
  res.setHeader("Cross-Origin-Opener-Policy", "same-origin");
  res.setHeader("Cross-Origin-Embedder-Policy", "require-corp");
  next();
});

// ✅ wasm MIME: 문자열 패턴 대신 정규식 사용
app.get(/.*\.wasm$/, (req, res, next) => {
  res.type("application/wasm");
  next();
});

// ✅ 정적 파일 제공
app.use(express.static(webDir, { fallthrough: true }));

// ✅ SPA fallback: "*" 대신 정규식으로 처리 (path-to-regexp 충돌 회피)
app.get(/.*/, (req, res) => {
  res.sendFile(path.join(webDir, "index.html"));
});

app.listen(5000, () => {
  console.log("Serving build/web at http://localhost:5000");
});