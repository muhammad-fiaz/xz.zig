import { defineConfig } from "vitepress";

export const SITE_URL = "https://muhammad-fiaz.github.io/xz.zig";
export const SITE_NAME = "xz.zig";
export const SITE_DESCRIPTION =
  "Native Zig XZ container compression library. Full multi-block streaming, CRC32, CRC64, SHA-256 checks, Delta and BCJ filters, zero external C dependencies.";

export const GA_ID = "G-6BVYCRK57P";
export const GTM_ID = "GTM-P4M9T8ZR";
export const ADSENSE_CLIENT_ID = "ca-pub-2040560600290490";

export const KEYWORDS =
  "zig, xz, lzma2, compression, decompression, container, stream, format, crc32, crc64, sha256, delta-filter, bcj-filter, native, pure-zig, zig-0.17";

export default defineConfig({
  lang: "en-US",
  title: SITE_NAME,
  titleTemplate: ":title | xz.zig",
  description: SITE_DESCRIPTION,
  base: "/xz.zig/",
  lastUpdated: true,
  cleanUrls: false,

  sitemap: {
    hostname: "https://muhammad-fiaz.github.io/xz.zig/",
  },

  head: [
    ["meta", { name: "author", content: "Muhammad Fiaz" }],
    ["meta", { name: "robots", content: "index, follow" }],
    ["meta", { name: "language", content: "English" }],
    ["meta", { name: "revisit-after", content: "7 days" }],
    ["meta", { name: "generator", content: "VitePress" }],

    ["meta", { property: "og:type", content: "website" }],
    [
      "meta",
      {
        property: "og:image",
        content: `${SITE_URL}/favicon.svg`,
      },
    ],
    [
      "meta",
      {
        property: "og:image:alt",
        content: "xz.zig - Native Zig XZ container compression library",
      },
    ],
    ["meta", { property: "og:site_name", content: SITE_NAME }],
    ["meta", { property: "og:locale", content: "en_US" }],

    ["meta", { name: "twitter:card", content: "summary" }],
    [
      "meta",
      {
        name: "twitter:image",
        content: `${SITE_URL}/favicon.svg`,
      },
    ],
    [
      "meta",
      {
        name: "twitter:image:alt",
        content: "xz.zig - Native Zig XZ container compression library",
      },
    ],
    ["meta", { name: "twitter:site", content: "@muhammadfiaz_" }],
    ["meta", { name: "twitter:creator", content: "@muhammadfiaz_" }],

    ["link", { rel: "icon", type: "image/svg+xml", href: "/xz.zig/favicon.svg" }],
    ["link", { rel: "icon", type: "image/png", sizes: "32x32", href: "/xz.zig/favicon.svg" }],

    ["meta", { name: "theme-color", content: "#0284c7" }],
    ["meta", { name: "msapplication-TileColor", content: "#0284c7" }],

    [
      "script",
      {
        async: "",
        src: `https://www.googletagmanager.com/gtag/js?id=${GA_ID}`,
      },
    ],
    [
      "script",
      {},
      `window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('config', '${GA_ID}');`,
    ],

    ...(GTM_ID
      ? ([
          [
            "script",
            {},
            `(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start': new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0], j=d.createElement(s), dl=l!='dataLayer'?'&l='+l:''; j.async=true; j.src='https://www.googletagmanager.com/gtm.js?id='+i+dl; f.parentNode.insertBefore(j,f);})(window,document,'script','dataLayer','${GTM_ID}');`,
          ],
          [
            "noscript",
            {},
            `<iframe src="https://www.googletagmanager.com/ns.html?id=${GTM_ID}" height="0" width="0" style="display:none;visibility:hidden"></iframe>`,
          ],
        ] as [string, Record<string, string>, string][])
      : []),

    [
      "script",
      {
        async: "",
        src: `https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${ADSENSE_CLIENT_ID}`,
        crossorigin: "anonymous",
      },
    ],
  ],

  ignoreDeadLinks: [/.*\.zig$/],

  transformPageData(pageData: any) {
    const isHome = pageData.relativePath === "index.md";
    const pageTitle = pageData.title || (isHome ? "Native XZ Container Compression Library for Zig" : SITE_NAME);
    const fullTitle = `${pageTitle} | ${SITE_NAME}`;
    const pageDescription = pageData.frontmatter.description || pageData.description || SITE_DESCRIPTION;
    const pageKeywords = pageData.frontmatter.keywords
      ? `${pageData.frontmatter.keywords}, ${KEYWORDS}`
      : KEYWORDS;

    const normalizedPath = pageData.relativePath
      .replace(/\.md$/, "")
      .replace(/(^|\/)index$/, "$1")
      .replace(/\/$/, "");
    const canonicalUrl =
      normalizedPath.length > 0
        ? `${SITE_URL}/${normalizedPath}`
        : SITE_URL;

    pageData.frontmatter.head ??= [];
    pageData.frontmatter.head.push(
      ["link", { rel: "canonical", href: canonicalUrl }],
      ["meta", { name: "title", content: fullTitle }],
      ["meta", { name: "description", content: pageDescription }],
      ["meta", { name: "keywords", content: pageKeywords }],
      ["meta", { property: "og:title", content: fullTitle }],
      ["meta", { property: "og:description", content: pageDescription }],
      ["meta", { property: "og:url", content: canonicalUrl }],
      ["meta", { name: "twitter:title", content: fullTitle }],
      ["meta", { name: "twitter:description", content: pageDescription }],
      ["meta", { name: "twitter:url", content: canonicalUrl }],
    );

    const lastUpdated = pageData.lastUpdated
      ? new Date(pageData.lastUpdated).toISOString()
      : new Date().toISOString();

    const graph: any[] = [];

    if (isHome) {
      graph.push({
        "@type": "WebSite",
        name: SITE_NAME,
        url: SITE_URL,
        description: SITE_DESCRIPTION,
        author: {
          "@type": "Person",
          name: "Muhammad Fiaz",
          url: "https://github.com/muhammad-fiaz",
        },
      });
    }

    const authorSchema = {
      "@type": "Person",
      name: "Muhammad Fiaz",
      url: "https://muhammadfiaz.com",
      sameAs: [
        "https://github.com/muhammad-fiaz",
        "https://www.linkedin.com/in/muhammad-fiaz-",
        "https://x.com/muhammadfiaz_",
      ],
    };

    const primarySchema: Record<string, any> = {
      "@type": isHome ? "SoftwareApplication" : "TechArticle",
      name: isHome ? SITE_NAME : pageTitle,
      description: pageDescription,
      url: canonicalUrl,
      image: `${SITE_URL}/favicon.svg`,
      author: authorSchema,
      publisher: {
        "@type": "Organization",
        name: "xz.zig",
        url: SITE_URL,
      },
    };

    if (isHome) {
      Object.assign(primarySchema, {
        applicationCategory: "DeveloperApplication",
        operatingSystem: "Cross-platform",
        programmingLanguage: "Zig",
        offers: {
          "@type": "Offer",
          price: "0",
          priceCurrency: "USD",
        },
        downloadUrl: "https://github.com/muhammad-fiaz/xz.zig",
        license: "https://opensource.org/licenses/MIT",
        featureList: [
          "Pure native Zig targeting Zig 0.17.0",
          "Official XZ container format (Stream Header, Blocks, Index, Stream Footer)",
          "Integrity checks: None, CRC32, CRC64, SHA-256",
          "LZMA2 compression via independent lzma2.zig package dependency",
          "Delta and x86 BCJ branch filter pipelines",
          "One-shot compression and decompression (xz.compress, xz.decompress)",
          "Zero-allocation caller-buffer operations (compressInto, decompressInto)",
          "Streaming pipelines (compressStream, decompressStream)",
          "Zero external C dependencies, zero @cImport, no libc",
        ],
      });
    } else {
      const pathParts = pageData.relativePath.split("/");
      const section =
        pathParts.length > 1
          ? pathParts[0].charAt(0).toUpperCase() + pathParts[0].slice(1)
          : "Documentation";

      Object.assign(primarySchema, {
        headline: pageTitle,
        articleSection: section,
        mainEntityOfPage: {
          "@type": "WebPage",
          "@id": canonicalUrl,
        },
        datePublished: "2026-01-01T00:00:00Z",
        dateModified: lastUpdated,
      });
    }
    graph.push(primarySchema);

    const breadcrumbs: any[] = [
      {
        "@type": "ListItem",
        position: 1,
        name: "Home",
        item: SITE_URL,
      },
    ];

    if (!isHome) {
      const pathParts = pageData.relativePath.replace(/\.md$/, "").split("/");
      let currentPath = SITE_URL;
      for (let i = 0; i < pathParts.length; i++) {
        const part = pathParts[i];
        if (part === "index") continue;
        currentPath += `/${part}`;
        breadcrumbs.push({
          "@type": "ListItem",
          position: breadcrumbs.length + 1,
          name: part.charAt(0).toUpperCase() + part.slice(1).replace(/-/g, " "),
          item: currentPath,
        });
      }
    }

    graph.push({
      "@type": "BreadcrumbList",
      itemListElement: breadcrumbs,
    });

    pageData.frontmatter.head.push([
      "script",
      { type: "application/ld+json" },
      JSON.stringify({
        "@context": "https://schema.org",
        "@graph": graph,
      }),
    ]);
  },

  themeConfig: {
    siteTitle: "xz.zig",

    nav: [
      { text: "Home", link: "/" },
      { text: "Guide", link: "/guide/getting-started" },
      { text: "API", link: "/api/" },
      { text: "Examples", link: "/examples/" },
      { text: "Security", link: "https://github.com/muhammad-fiaz/xz.zig/blob/main/SECURITY.md" },
      {
        text: "Support",
        items: [
          {
            text: "Sponsor",
            link: "https://github.com/sponsors/muhammad-fiaz",
          },
          { text: "Donate", link: "https://pay.muhammadfiaz.com" },
        ],
      },
      { text: "GitHub", link: "https://github.com/muhammad-fiaz/xz.zig" },
    ],

    sidebar: [
      {
        text: "Guide",
        items: [
          { text: "Getting Started", link: "/guide/getting-started" },
          { text: "Installation", link: "/guide/installation" },
          { text: "Container Format & Framing", link: "/guide/format-notes" },
          { text: "Compression", link: "/guide/compression" },
          { text: "Decompression", link: "/guide/decompression" },
          { text: "Memory Management & Safety", link: "/guide/memory-management" },
          { text: "Troubleshooting & FAQ", link: "/guide/troubleshooting" },
        ],
      },
      {
        text: "API Reference",
        items: [
          { text: "Overview", link: "/api/" },
          { text: "Options & Checks", link: "/api/options" },
          { text: "Compression API", link: "/api/compressor" },
          { text: "Decompression API", link: "/api/decompressor" },
          { text: "Constants & Filter IDs", link: "/api/constants" },
          { text: "Error Sets", link: "/api/errors" },
        ],
      },
      {
        text: "Examples",
        items: [
          { text: "Overview", link: "/examples/" },
          { text: "Basic Compression", link: "/examples/basic_compression" },
          { text: "Caller Buffers", link: "/examples/caller_buffer" },
          { text: "Checksum Types", link: "/examples/checksum_types" },
          { text: "Filter Chains (BCJ & Delta)", link: "/examples/filter_chains" },
          { text: "Streaming Pipeline", link: "/examples/streaming_pipeline" },
          { text: "Error Handling", link: "/examples/error_handling" },
        ],
      },
    ],

    socialLinks: [
      { icon: "github", link: "https://github.com/muhammad-fiaz/xz.zig" },
    ],

    footer: {
      message: "Released under the MIT License.",
      copyright: "Copyright © 2026 Muhammad Fiaz",
    },

    search: {
      provider: "local",
    },

    editLink: {
      pattern:
        "https://github.com/muhammad-fiaz/xz.zig/edit/main/docs/:path",
      text: "Edit this page on GitHub",
    },

    lastUpdated: {
      text: "Last updated",
      formatOptions: {
        dateStyle: "medium",
        timeStyle: "short",
      },
    },
  },
});
