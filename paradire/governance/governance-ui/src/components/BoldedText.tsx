export default function BoldedText({
  text,
  bold,
}: {
  text: string;
  bold: string;
}) {
  const textArray = text.split(RegExp(bold, "ig"));
  const match = text.match(RegExp(bold, "ig"));

  return textArray.map((item, index) => (
    <span key={index}>
      {item}
      {index !== textArray.length - 1 && match && (
        <span className="font-bold text-green-600 text-lg">{match[index]}</span>
      )}
    </span>
  ));
}
