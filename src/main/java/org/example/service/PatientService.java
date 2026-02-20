package org.example.service;

import org.example.dto.PatientRequestDTO;
import org.example.dto.PatientResponseDTO;
import org.example.mapper.PatientMapper;
import org.example.model.Patient;
import org.example.repository.PatientRepository;
import org.springframework.stereotype.Service;
import java.util.*;
@Service
public class PatientService {
    private PatientRepository patientRepository;

    public PatientService(PatientRepository patientRepository){
        this.patientRepository = patientRepository;
    }

    public List<PatientResponseDTO> getPatients(){
        List<Patient> patients = patientRepository.findAll();

        List<PatientResponseDTO> patientResponseDTOS=
                patients.stream().map(
                        patient
                        -> PatientMapper.toDTO(patient)
                ).toList();

        return patientResponseDTOS;
    }

    public PatientResponseDTO createPatient(PatientRequestDTO patientRequestDTO){
        Patient newPatient = patientRepository.save(PatientMapper.toModel(patientRequestDTO));
            return PatientMapper.toDTO(newPatient);
    }
}
