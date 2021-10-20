import { h } from 'preact';

export const Bold = () => (
  <svg
    className="crayons-icon"
    height="24"
    viewBox="0 0 24 24"
    width="24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path d="m8 11h4.5c.663 0 1.2989-.2634 1.7678-.7322.4688-.46887.7322-1.10476.7322-1.7678s-.2634-1.29893-.7322-1.76777c-.4689-.46884-1.1048-.73223-1.7678-.73223h-4.5zm10 4.5c0 .5909-.1164 1.1761-.3425 1.7221-.2262.5459-.5577 1.042-.9755 1.4599-.4179.4178-.914.7493-1.4599.9755-.546.2261-1.1312.3425-1.7221.3425h-7.5v-16h6.5c.881.00004 1.7425.25865 2.4779.74378.7353.48512 1.3121 1.17542 1.6588 1.98529s.448 1.70369.2915 2.57062c-.1566.86691-.5641 1.66881-1.1722 2.30631.6826.3953 1.2493.9632 1.6432 1.6466.3939.6835.6011 1.4586.6008 2.2474zm-10-2.5v5h5.5c.663 0 1.2989-.2634 1.7678-.7322.4688-.4689.7322-1.1048.7322-1.7678s-.2634-1.2989-.7322-1.7678c-.4689-.4688-1.1048-.7322-1.7678-.7322z" />
  </svg>
);

export const Italic = () => (
  <svg
    className="crayons-icon"
    width="24"
    height="24"
    viewBox="0 0 24 24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path
      d="M15 20H7V18H9.927L12.043 6H9V4H17V6H14.073L11.957 18H15V20Z"
      fill="black"
    />
  </svg>
);

export const Link = () => (
  <svg
    className="crayons-icon"
    height="24"
    viewBox="0 0 24 24"
    width="24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path d="m18.364 15.536-1.414-1.416 1.414-1.414c.4676-.4636.8391-1.0149 1.0931-1.6224.2539-.6075.3854-1.2592.3869-1.91765.0014-.65845-.1272-1.3107-.3785-1.9193-.2513-.60861-.6204-1.16158-1.086-1.62718s-1.0186-.83464-1.6272-1.08596c-.6086-.25131-1.2608-.37994-1.9193-.37849-.6584.00144-1.3101.13292-1.9176.3869-.6075.25397-1.1589.62544-1.6224 1.09307l-1.414 1.415-1.415-1.414 1.416-1.414c1.3128-1.31282 3.0934-2.05036 4.95-2.05036s3.6372.73754 4.95 2.05036 2.0504 3.09339 2.0504 4.95-.7376 3.63721-2.0504 4.95001l-1.415 1.414zm-2.828 2.828-1.415 1.414c-1.3128 1.3128-3.0934 2.0503-4.95 2.0503-1.85661 0-3.63718-.7375-4.95-2.0503-1.31283-1.3128-2.05036-3.0934-2.05036-4.95s.73753-3.6372 2.05036-4.95001l1.415-1.414 1.414 1.416-1.414 1.41401c-.46763.4635-.8391 1.0149-1.09308 1.6224-.25397.6075-.38545 1.2592-.3869 1.9176-.00144.6585.12719 1.3107.3785 1.9193s.62036 1.1616 1.08596 1.6272c.46559.4656 1.01857.8347 1.62717 1.086.60861.2513 1.26086.3799 1.91931.3785.65845-.0015 1.31014-.133 1.91764-.3869.6075-.254 1.1588-.6255 1.6224-1.0931l1.414-1.414 1.415 1.414zm-.708-10.60701 1.415 1.415-7.071 7.07001-1.415-1.414 7.071-7.07001z" />
  </svg>
);

export const OrderedList = () => (
  <svg
    className="crayons-icon"
    height="24"
    viewBox="0 0 24 24"
    width="24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path d="m8 4h13v2h-13zm-3-1v3h1v1h-3v-1h1v-2h-1v-1zm-2 11v-2.5h2v-.5h-2v-1h3v2.5h-2v.5h2v1zm2 5.5h-2v-1h2v-.5h-2v-1h3v4h-3v-1h2zm3-8.5h13v2h-13zm0 7h13v2h-13z" />
  </svg>
);

export const UnorderedList = () => (
  <svg
    className="crayons-icon"
    height="24"
    viewBox="0 0 24 24"
    width="24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path d="m8 4h13v2h-13zm-3.5 2.5c-.39782 0-.77936-.15804-1.06066-.43934s-.43934-.66284-.43934-1.06066.15804-.77936.43934-1.06066.66284-.43934 1.06066-.43934.77936.15804 1.06066.43934.43934.66284.43934 1.06066-.15804.77936-.43934 1.06066-.66284.43934-1.06066.43934zm0 7c-.39782 0-.77936-.158-1.06066-.4393s-.43934-.6629-.43934-1.0607.15804-.7794.43934-1.0607.66284-.4393 1.06066-.4393.77936.158 1.06066.4393.43934.6629.43934 1.0607-.15804.7794-.43934 1.0607-.66284.4393-1.06066.4393zm0 6.9c-.39782 0-.77936-.158-1.06066-.4393s-.43934-.6629-.43934-1.0607.15804-.7794.43934-1.0607.66284-.4393 1.06066-.4393.77936.158 1.06066.4393.43934.6629.43934 1.0607-.15804.7794-.43934 1.0607-.66284.4393-1.06066.4393zm3.5-9.4h13v2h-13zm0 7h13v2h-13z" />
  </svg>
);

export const Heading = () => (
  <svg
    className="crayons-icon"
    height="24"
    viewBox="0 0 24 24"
    width="24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path d="m17 11v-7h2v17h-2v-8h-10v8h-2v-17h2v7z" />
  </svg>
);

export const Quote = () => (
  <svg
    className="crayons-icon"
    height="24"
    viewBox="0 0 24 24"
    width="24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path d="m4.583 17.321c-1.03-1.094-1.583-2.321-1.583-4.31 0-3.5 2.457-6.637 6.03-8.188l.893 1.378c-3.335 1.804-3.987 4.145-4.247 5.621.537-.278 1.24-.375 1.929-.311 1.804.167 3.226 1.648 3.226 3.489 0 .9283-.3687 1.8185-1.02513 2.4749-.65637.6563-1.54661 1.0251-2.47487 1.0251-1.073 0-2.099-.49-2.748-1.179zm10 0c-1.03-1.094-1.583-2.321-1.583-4.31 0-3.5 2.457-6.637 6.03-8.188l.893 1.378c-3.335 1.804-3.987 4.145-4.247 5.621.537-.278 1.24-.375 1.929-.311 1.804.167 3.226 1.648 3.226 3.489 0 .9283-.3687 1.8185-1.0251 2.4749-.6564.6563-1.5466 1.0251-2.4749 1.0251-1.073 0-2.099-.49-2.748-1.179z" />
  </svg>
);

export const Code = () => (
  <svg
    className="crayons-icon"
    height="24"
    viewBox="0 0 24 24"
    width="24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path d="m23 12-7.071 7.071-1.414-1.414 5.657-5.657-5.657-5.65704 1.414-1.414zm-19.172 0 5.657 5.657-1.414 1.414-7.071-7.071 7.071-7.07104 1.414 1.414z" />
  </svg>
);

export const CodeBlock = () => (
  <svg
    className="crayons-icon"
    height="24"
    viewBox="0 0 24 24"
    width="24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path d="m3 3h18c.2652 0 .5196.10536.7071.29289.1875.18754.2929.44189.2929.70711v16c0 .2652-.1054.5196-.2929.7071s-.4419.2929-.7071.2929h-18c-.26522 0-.51957-.1054-.70711-.2929-.18753-.1875-.29289-.4419-.29289-.7071v-16c0-.26522.10536-.51957.29289-.70711.18754-.18753.44189-.29289.70711-.29289zm1 2v14h16v-14zm15 7-3.536 3.536-1.414-1.415 2.122-2.121-2.122-2.121 1.414-1.415zm-11.172 0 2.122 2.121-1.414 1.415-3.536-3.536 3.536-3.536 1.414 1.416z" />
  </svg>
);

export const Overflow = () => (
  <svg
    className="crayons-icon"
    height="24"
    viewBox="0 0 24 24"
    width="24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path
      clip-rule="evenodd"
      d="m12 17c1.1046 0 2 .8954 2 2s-.8954 2-2 2-2-.8954-2-2 .8954-2 2-2zm0-7c1.1046 0 2 .8954 2 2s-.8954 2-2 2-2-.8954-2-2 .8954-2 2-2zm2-5c0-1.10457-.8954-2-2-2s-2 .89543-2 2 .8954 2 2 2 2-.89543 2-2z"
      fill-rule="evenodd"
    />
  </svg>
);

export const Underline = () => (
  <svg
    className="crayons-icon"
    height="24"
    viewBox="0 0 24 24"
    width="24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path d="m8 3v9c0 1.0609.42143 2.0783 1.17157 2.8284.75015.7502 1.76753 1.1716 2.82843 1.1716s2.0783-.4214 2.8284-1.1716c.7502-.7501 1.1716-1.7675 1.1716-2.8284v-9h2v9c0 1.5913-.6321 3.1174-1.7574 4.2426-1.1252 1.1253-2.6513 1.7574-4.2426 1.7574s-3.11742-.6321-4.24264-1.7574c-1.12522-1.1252-1.75736-2.6513-1.75736-4.2426v-9zm-4 17h16v2h-16z" />
  </svg>
);

export const Strikethrough = () => (
  <svg
    className="crayons-icon"
    height="24"
    viewBox="0 0 24 24"
    width="24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path d="m17.154 14c.23.516.346 1.09.346 1.72 0 1.342-.524 2.392-1.571 3.147-1.049.755-2.496 1.133-4.343 1.133-1.64 0-3.263-.381-4.87-1.144v-2.256c1.52.877 3.075 1.316 4.666 1.316 2.551 0 3.83-.732 3.839-2.197.0053-.297-.0494-.5921-.1607-.8675-.1114-.2754-.2771-.5256-.4873-.7355l-.12-.117h-11.453v-2h18v2h-3.846zm-4.078-3h-5.447c-.17517-.1597-.33611-.3344-.481-.522-.432-.558-.648-1.232-.648-2.026 0-1.236.466-2.287 1.397-3.153.933-.866 2.374-1.299 4.325-1.299 1.471 0 2.879.328 4.222.984v2.152c-1.2-.687-2.515-1.03-3.946-1.03-2.48 0-3.719.782-3.719 2.346 0 .42.218.786.654 1.099s.974.562 1.613.75c.62.18 1.297.414 2.03.699z" />
  </svg>
);

export const Divider = () => (
  <svg
    className="crayons-icon"
    height="24"
    viewBox="0 0 24 24"
    width="24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <g>
      <path d="m2 11h6v2h-6z" />
      <path d="m2 11h6v2h-6z" />
      <path d="m9 11h6v2h-6z" />
      <path d="m16 11h6v2h-6z" />
      <g clip-rule="evenodd" fill-rule="evenodd">
        <path d="m12 6.58574-2.29288-2.29289-1.41421 1.41421 3.70709 3.70711 3.7071-3.70711-1.4142-1.41421z" />
        <path d="m12 17.4143-2.29288 2.2929-1.41421-1.4143 3.70709-3.7071 3.7071 3.7071-1.4142 1.4143z" />
      </g>
    </g>
  </svg>
);

export const Help = () => (
  <svg
    className="crayons-icon"
    height="24"
    viewBox="0 0 24 24"
    width="24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path d="m12 22c-5.523 0-10-4.477-10-10s4.477-10 10-10 10 4.477 10 10-4.477 10-10 10zm0-2c2.1217 0 4.1566-.8429 5.6569-2.3431 1.5002-1.5003 2.3431-3.5352 2.3431-5.6569 0-2.12173-.8429-4.15656-2.3431-5.65685-1.5003-1.5003-3.5352-2.34315-5.6569-2.34315-2.12173 0-4.15656.84285-5.65685 2.34315-1.5003 1.50029-2.34315 3.53512-2.34315 5.65685 0 2.1217.84285 4.1566 2.34315 5.6569 1.50029 1.5002 3.53512 2.3431 5.65685 2.3431zm-1-5h2v2h-2zm2-1.645v.645h-2v-1.5c0-.2652.1054-.5196.2929-.7071s.4419-.2929.7071-.2929c.2841 0 .5623-.0807.8023-.2327.24-.1519.432-.3689.5535-.6257s.1676-.5428.1329-.82476c-.0347-.28195-.1487-.54826-.3289-.76793-.1801-.21967-.4189-.38368-.6886-.47294s-.5592-.1001-.8348-.03126c-.2756.06883-.526.21452-.722.42011-.1961.20558-.3297.46261-.3854.74118l-1.962-.393c.12163-.60792.40251-1.17263.81392-1.63641.41141-.46379.93858-.81001 1.52768-1.00327s1.2189-.22663 1.8251-.09671c.6062.12993 1.167.4185 1.6251.83621.4581.41772.7971.94959.9823 1.54124.1852.59166.21 1.22184.0718 1.82624s-.4344 1.1612-.8584 1.6136c-.4239.4523-.9604.784-1.5545.9611z" />
  </svg>
);
