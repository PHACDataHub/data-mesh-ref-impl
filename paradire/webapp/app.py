from flask import Flask, render_template, request, redirect, url_for, flash
from flask_wtf import FlaskForm
from flask_cors import CORS
from wtforms import SelectMultipleField, IntegerField, SubmitField
from wtforms.validators import DataRequired
import subprocess
import os
import requests
from flask import jsonify


app = Flask(__name__)
app.config['SECRET_KEY'] =  '3d6f45a5fc12445dbac2f59c3b6c7cb1'
CORS(app)


PROVINCES_TERRITORIES = [
    ('AB', 'Alberta'), 
    ('BC', 'British Columbia'), 
    ('MB', 'Manitoba'),
    ('NB', 'New Brunswick'), 
    ('NL', 'Newfoundland and Labrador'),
    ('NS', 'Nova Scotia'), 
    ('NT', 'Northwest Territories'), 
    ('NU', 'Nunavut'),
    ('ON', 'Ontario'), 
    ('PE', 'Prince Edward Island'), 
    ('QC', 'Quebec'),
    ('SK', 'Saskatchewan'), 
    ('YT', 'Yukon')
]

class DataUploadForm(FlaskForm):
    provinces = SelectMultipleField('Provinces/Territories', choices=PROVINCES_TERRITORIES, validators=[DataRequired()])
    sampling_size = IntegerField('Sampling Size', default=10, validators=[DataRequired()])
    submit = SubmitField('Upload Data')

@app.route('/', methods=['GET', 'POST'])
def index():
    form = DataUploadForm()
    if form.validate_on_submit():
        
        current_dir = os.getcwd()
        os.chdir('..')
        generate_command = os.path.join('./generate_patient_population.sh')
        upload_command = os.path.join('./upload_pt_ehrs.sh')

        results = []
        for province in form.provinces.data:
            # Check if FHIR server is up before generating and uploading for each province
            if not is_fhir_server_up():
                return jsonify(status="error", message="FHIR Server is down. Please ensure it is running before proceeding.")

            gen_result = subprocess.run([generate_command, str(form.sampling_size.data), 'ca_spp', province])           
            if gen_result.returncode != 0:
                results.append({"province": province, "status": "failed", "step": "generation"})
                continue
            
            upload_result = subprocess.run([upload_command, 'ca_spp', province])
            if upload_result.returncode != 0:
                results.append({"province": province, "status": "failed", "step": "upload"})
                continue
            
            results.append({"province": province, "status": "success"})
        
        os.chdir(current_dir)

        # Return the results in JSON format for AJAX requests
        if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
            return jsonify(results=results)
        else:
            flash('Data upload initiated for the selected provinces/territories.', 'success')
            return redirect(url_for('index'))

    return render_template('index.html', form=form)


def is_fhir_server_up():
    try:
        response = requests.get('http://localhost:8080/')
        return response.status_code == 200
    except requests.RequestException:
        return False

@app.route('/health_check')
def health_check():
    if is_fhir_server_up():
        return "FHIR Server is UP", 200
    else:
        return "FHIR Server is DOWN", 503

if __name__ == '__main__':
    app.run(debug=True)