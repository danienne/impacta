function calculateImc(evt) {
    var heightElem = document.querySelector("#altura");
    var weightElem = document.querySelector("#peso");

    if (!heightElem) throw Error("height is required field!");
    if (!weightElem) throw Error("weight is required field!");

    var height = heightElem.value;
    var weight = weightElem.value;

    var person = new Person(parseFloat(height), parseFloat(weight));
    var imc = person.weight * person.weight / person.height;
    var imcMessage = "";

    if (imc < 18.5) {
        imcMessage = "Magreza, quando o resultado &eacute; menor que 18,5 kg/m2;"
    } else if (imc < 24.9) {
        imcMessage = "Normal, quando o resultado esta entre 18,5 e 24,9 kg/m2;"
    } else if (imc < 30) {
        imcMessage = "Sobrepeso, quando o resultado esta entre 24,9 e 30 kg/m2;"
    } else {
        imcMessage = "Obesidade, quando o resultado &eacute; maior que 30 kg/m2;"
    }

    var imcElem = document.querySelector("#imc");
    imcElem.innerHTML = imcMessage;
}



window.onload = function(evt) {
    var btn = document.querySelector(".data .form button");
    btn.addEventListener("click", calculateImc);
};