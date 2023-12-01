import { Html, Head, Main, NextScript } from "next/document";

export default function Document() {
  return (
    <Html lang="en" className=" h-full flex">
      <Head />
      <body className="m-2 flex flex-1 flex-col">
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}
