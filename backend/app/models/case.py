"""
Case model for database interactions using SQLAlchemy
Handles case creation, storage, and retrieval
"""
from app import db
from datetime import datetime
import json


class Case(db.Model):
    """Case model for managing patient case data with SQLAlchemy"""
    
    __tablename__ = 'cases'
    
    # Columns
    id = db.Column(db.Integer, primary_key=True)
    patient_name = db.Column(db.String(255), nullable=False)
    patient_id = db.Column(db.String(50), nullable=False)
    date = db.Column(db.String(50), nullable=False)
    surgery_type = db.Column(db.String(255), nullable=False)
    anesthetic_agent = db.Column(db.String(255), nullable=False)
    molecular_mass = db.Column(db.String(50), nullable=False)
    vapor_constant = db.Column(db.String(50), nullable=False)
    density = db.Column(db.String(50), nullable=False)
    fresh_gas_flow = db.Column(db.Float, nullable=True)
    dial_concentration = db.Column(db.Float, nullable=True)
    time_minutes = db.Column(db.Float, nullable=True)
    initial_weight = db.Column(db.Float, nullable=True)
    final_weight = db.Column(db.Float, nullable=True)
    biro_formula = db.Column(db.Float, nullable=True)
    dion_formula = db.Column(db.Float, nullable=True)
    weight_based = db.Column(db.Float, nullable=True)
    notes = db.Column(db.Text, nullable=True)
    induction_fgf = db.Column(db.Float, nullable=True)
    induction_concentration = db.Column(db.Float, nullable=True)
    induction_time = db.Column(db.Float, nullable=True)
    induction_biro = db.Column(db.Float, nullable=True)
    induction_dion = db.Column(db.Float, nullable=True)
    final_biro = db.Column(db.Float, nullable=True)
    final_dion = db.Column(db.Float, nullable=True)
    maintenance_rows = db.Column(db.Text, nullable=True)
    maintenance_calculations = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<Case {self.patient_name} - {self.surgery_type}>'
    
    def to_dict(self):
        """
        Convert case object to dictionary
        
        Returns:
            Dictionary representation of case
        """
        maintenance_rows = []
        maintenance_calculations = []

        if self.maintenance_rows:
            try:
                maintenance_rows = json.loads(self.maintenance_rows)
            except Exception:
                maintenance_rows = []

        if self.maintenance_calculations:
            try:
                maintenance_calculations = json.loads(self.maintenance_calculations)
            except Exception:
                maintenance_calculations = []

        return {
            'id': self.id,
            'patient_name': self.patient_name,
            'patient_id': self.patient_id,
            'date': self.date,
            'surgery_type': self.surgery_type,
            'anesthetic_agent': self.anesthetic_agent,
            'molecular_mass': self.molecular_mass,
            'vapor_constant': self.vapor_constant,
            'density': self.density,
            'fresh_gas_flow': self.fresh_gas_flow,
            'dial_concentration': self.dial_concentration,
            'time_minutes': self.time_minutes,
            'initial_weight': self.initial_weight,
            'final_weight': self.final_weight,
            'biro_formula': self.biro_formula,
            'dion_formula': self.dion_formula,
            'weight_based': self.weight_based,
            'notes': self.notes,
            'induction_fgf': self.induction_fgf,
            'induction_concentration': self.induction_concentration,
            'induction_time': self.induction_time,
            'induction_biro': self.induction_biro,
            'induction_dion': self.induction_dion,
            'final_biro': self.final_biro,
            'final_dion': self.final_dion,
            'maintenance_rows': maintenance_rows,
            'maintenance_calculations': maintenance_calculations,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
    
    @staticmethod
    def create(patient_name, patient_id, date, surgery_type, anesthetic_agent,
               molecular_mass, vapor_constant, density, fresh_gas_flow=None,
               dial_concentration=None, time_minutes=None, initial_weight=None,
               final_weight=None, biro_formula=None, dion_formula=None,
               weight_based=None, notes=None, induction_fgf=None,
               induction_concentration=None, induction_time=None,
               induction_biro=None, induction_dion=None, final_biro=None,
               final_dion=None, maintenance_rows=None,
               maintenance_calculations=None):
        """
        Create a new case in the database
        
        Args:
            patient_name: Name of patient
            patient_id: Patient ID
            date: Date of case
            surgery_type: Type of surgery
            anesthetic_agent: Anesthetic agent used
            molecular_mass: Molecular mass value
            vapor_constant: Vapor constant value
            density: Density value
        
        Returns:
            Dictionary with success status and case data or error message
        """
        try:
            # Create new case instance
            new_case = Case(
                patient_name=patient_name,
                patient_id=patient_id,
                date=date,
                surgery_type=surgery_type,
                anesthetic_agent=anesthetic_agent,
                molecular_mass=molecular_mass,
                vapor_constant=vapor_constant,
                density=density,
                fresh_gas_flow=fresh_gas_flow,
                dial_concentration=dial_concentration,
                time_minutes=time_minutes,
                initial_weight=initial_weight,
                final_weight=final_weight,
                biro_formula=biro_formula,
                dion_formula=dion_formula,
                weight_based=weight_based,
                notes=notes,
                induction_fgf=induction_fgf,
                induction_concentration=induction_concentration,
                induction_time=induction_time,
                induction_biro=induction_biro,
                induction_dion=induction_dion,
                final_biro=final_biro,
                final_dion=final_dion,
                maintenance_rows=json.dumps(maintenance_rows or []),
                maintenance_calculations=json.dumps(maintenance_calculations or [])
            )
            
            # Add to session and commit
            db.session.add(new_case)
            db.session.commit()
            
            return {
                'success': True,
                'id': new_case.id,
                'patient_name': new_case.patient_name,
                'patient_id': new_case.patient_id,
                'date': new_case.date
            }
        
        except Exception as e:
            db.session.rollback()
            return {
                'success': False,
                'error': f'Failed to save case: {str(e)}'
            }
    
    @staticmethod
    def get_all():
        """
        Fetch all cases from database
        
        Returns:
            List of case dictionaries sorted by latest first
        """
        try:
            cases = Case.query.order_by(Case.created_at.desc()).all()
            return {
                'success': True,
                'cases': [case.to_dict() for case in cases],
                'count': len(cases)
            }
        
        except Exception as e:
            return {
                'success': False,
                'error': f'Failed to fetch cases: {str(e)}'
            }
    
    @staticmethod
    def get_by_id(case_id):
        """
        Fetch a specific case by ID
        
        Args:
            case_id: Case ID
        
        Returns:
            Case dictionary or None
        """
        try:
            case = Case.query.filter_by(id=case_id).first()
            if case:
                return {
                    'success': True,
                    'case': case.to_dict()
                }
            return {
                'success': False,
                'error': 'Case not found'
            }
        
        except Exception as e:
            return {
                'success': False,
                'error': f'Failed to fetch case: {str(e)}'
            }
    
    @staticmethod
    def delete(case_id):
        """
        Delete a case by ID
        
        Args:
            case_id: Case ID
        
        Returns:
            Dictionary with success status
        """
        try:
            case = Case.query.filter_by(id=case_id).first()
            if case:
                db.session.delete(case)
                db.session.commit()
                return {
                    'success': True,
                    'message': 'Case deleted successfully'
                }
            return {
                'success': False,
                'error': 'Case not found'
            }
        
        except Exception as e:
            db.session.rollback()
            return {
                'success': False,
                'error': f'Failed to delete case: {str(e)}'
            }
