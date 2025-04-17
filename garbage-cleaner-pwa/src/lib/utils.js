import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

/**
 * Combines multiple class names and merges Tailwind CSS classes
 * @param {...string} inputs - Class names to merge
 * @returns {string} - Merged class string
 */
export function cn(...inputs) {
  return twMerge(clsx(inputs));
} 