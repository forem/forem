import { h } from 'preact';
import BoldIcon from '@images/bold.svg';
import ItalicIcon from '@images/italic.svg';
import LinkIcon from '@images/link.svg';
import OrderedListIcon from '@images/list-ordered.svg';
import UnorderedListIcon from '@images/list-unordered.svg';
import HeadingIcon from '@images/heading.svg';
import QuoteIcon from '@images/quote.svg';
import CodeIcon from '@images/code.svg';
import CodeBlockIcon from '@images/codeblock.svg';
import UnderlineIcon from '@images/underline.svg';
import StrikethroughIcon from '@images/strikethrough.svg';
import DividerIcon from '@images/divider.svg';
import { Icon } from '@crayons';

export const Bold = () => <Icon src={BoldIcon} />;

export const Italic = () => <Icon src={ItalicIcon} />;

export const Link = () => <Icon src={LinkIcon} />;

export const OrderedList = () => <Icon src={OrderedListIcon} />;

export const UnorderedList = () => <Icon src={UnorderedListIcon} />;

export const Heading = () => <Icon src={HeadingIcon} />;

export const Quote = () => <Icon src={QuoteIcon} />;

export const Code = () => <Icon src={CodeIcon} />;

export const CodeBlock = () => <Icon src={CodeBlockIcon} />;

export const Underline = () => <Icon src={UnderlineIcon} />;

export const Strikethrough = () => <Icon src={StrikethroughIcon} />;

export const Divider = () => <Icon src={DividerIcon} />;
