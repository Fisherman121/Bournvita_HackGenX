import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import sharp from 'sharp';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const publicDir = path.join(__dirname, 'public');

// Create a simple garbage bin logo
const generateLogo = async (size) => {
  // Create a green background with a garbage bin icon
  const svg = `
    <svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" xmlns="http://www.w3.org/2000/svg">
      <rect width="${size}" height="${size}" fill="#34d399"/>
      <g transform="translate(${size * 0.15}, ${size * 0.15}) scale(${size * 0.0007})">
        <path fill="#ffffff" d="M832 64h-192l-64-64h-256l-64 64h-192c-17.6 0-32 14.4-32 32v64c0 17.6 14.4 32 32 32h768c17.6 0 32-14.4 32-32v-64c0-17.6-14.4-32-32-32zM864 256l-64 768h-640l-64-768h768zM352 576c0-17.6-14.4-32-32-32s-32 14.4-32 32v352c0 17.6 14.4 32 32 32s32-14.4 32-32v-352zM544 576c0-17.6-14.4-32-32-32s-32 14.4-32 32v352c0 17.6 14.4 32 32 32s32-14.4 32-32v-352zM736 576c0-17.6-14.4-32-32-32s-32 14.4-32 32v352c0 17.6 14.4 32 32 32s32-14.4 32-32v-352z"/>
      </g>
    </svg>
  `;

  return sharp(Buffer.from(svg))
    .png()
    .toFile(path.join(publicDir, `garbage-logo-${size}.png`));
};

// Create favicon.ico
const generateFavicon = async () => {
  const svg = `
    <svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
      <rect width="64" height="64" fill="#34d399"/>
      <g transform="translate(10, 10) scale(0.045)">
        <path fill="#ffffff" d="M832 64h-192l-64-64h-256l-64 64h-192c-17.6 0-32 14.4-32 32v64c0 17.6 14.4 32 32 32h768c17.6 0 32-14.4 32-32v-64c0-17.6-14.4-32-32-32zM864 256l-64 768h-640l-64-768h768zM352 576c0-17.6-14.4-32-32-32s-32 14.4-32 32v352c0 17.6 14.4 32 32 32s32-14.4 32-32v-352zM544 576c0-17.6-14.4-32-32-32s-32 14.4-32 32v352c0 17.6 14.4 32 32 32s32-14.4 32-32v-352zM736 576c0-17.6-14.4-32-32-32s-32 14.4-32 32v352c0 17.6 14.4 32 32 32s32-14.4 32-32v-352z"/>
      </g>
    </svg>
  `;

  return sharp(Buffer.from(svg))
    .resize(64, 64)
    .toFormat('ico')
    .toFile(path.join(publicDir, 'favicon.ico'));
};

async function main() {
  try {
    // Ensure public directory exists
    if (!fs.existsSync(publicDir)) {
      fs.mkdirSync(publicDir, { recursive: true });
    }

    // Generate logos
    await Promise.all([
      generateLogo(192),
      generateLogo(512),
      generateFavicon()
    ]);

    console.log('Logos generated successfully!');
  } catch (error) {
    console.error('Error generating logos:', error);
  }
}

main(); 