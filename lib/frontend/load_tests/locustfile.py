from locust import HttpUser, task, between

class APIUser(HttpUser):
    wait_time = between(0.5, 2)

    @task(3)
    def get_health(self):
        self.client.get('/health', name='GET /health')

    @task(5)
    def list_cases(self):
        self.client.get('/cases', name='GET /cases')

    @task(2)
    def post_case(self):
        self.client.post('/cases', json={'title':'load test'}, name='POST /cases')

    @task(4)
    def calculator(self):
        self.client.post('/calculator/oxygen', json={'flow':1.0}, name='POST /calculator/oxygen')
