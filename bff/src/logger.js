export const emitLog = ({
  level = 'info',
  eventName,
  service = 'antiradar-bff',
  ...fields
}) => {
  // eslint-disable-next-line no-console
  console.log(
    JSON.stringify({
      timestamp: new Date().toISOString(),
      level,
      service,
      eventName,
      ...fields,
    }),
  );
};
